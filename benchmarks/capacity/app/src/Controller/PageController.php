<?php

namespace App\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\DependencyInjection\Attribute\Autowire;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

final class PageController extends AbstractController
{
    public function __construct(
        #[Autowire('%kernel.project_dir%/data/catalog.json')] private string $catalog,
        #[Autowire('%env(VISITS_DIR)%')] private string $visits,
        #[Autowire('%env(int:PAGE_ITEMS)%')] private int $items,
    ) {
    }

    #[Route('/health', methods: ['GET'])]
    public function health(): JsonResponse
    {
        return $this->json(['status' => 'ok']);
    }

    #[Route('/', methods: ['GET'])]
    public function page(Request $request): Response
    {
        $ballast = str_repeat('x', 1024 * 1024 * (int) ($_SERVER['PAGE_MEM_MB'] ?? getenv('PAGE_MEM_MB')));
        usleep(1000 * (int) ($_SERVER['IO_WAIT_MS'] ?? getenv('IO_WAIT_MS')));
        $products = json_decode((string) file_get_contents($this->catalog), true);
        $categories = array_values(array_unique(array_column($products, 'category')));
        sort($categories);
        $category = $request->query->get('category') ?? $categories[array_rand($categories)];
        $selection = array_filter($products, fn (array $p) => $p['category'] === $category || $p['rating'] >= 4.5);
        usort($selection, fn (array $a, array $b) => [$b['rating'], $a['price']] <=> [$a['rating'], $b['price']]);
        $selection = \array_slice($selection, 0, $this->items);

        $response = $this->render('page/catalog.html.twig', [
            'category' => $category,
            'categories' => $categories,
            'products' => $selection,
        ]);

        $visit = random_int(0, 999);
        file_put_contents("{$this->visits}/$visit.json", json_encode([
            'at' => date(\DATE_ATOM),
            'category' => $category,
            'products' => array_column($selection, 'id'),
            'agent' => $request->headers->get('User-Agent'),
        ]), \LOCK_EX);

        unset($ballast);

        return $response;
    }
}
